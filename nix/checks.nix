{
  lib,
  runCommand,
  writeTextDir,
  makeFontsConf,
  dejavu_fonts,
  jq,
  kdePackages,
  nixfmt,
  quickshell,
  qt6,
  shell-smoke,
}:

# What `nix flake check` runs. QML is only read when the shell starts, so a
# misspelt property, an import that is not there or a binding that throws
# shows up as a line in the log of a running shell and nowhere else; these
# turn the ones that can be caught ahead of time into a failed build.
#
#   lint    qmllint over every file, against quickshell's own type info
#   format  qmlformat and nixfmt, which the tree is already written in
#   smoke   the packaged shell, started under a headless compositor and
#           walked through every page — see smoke.sh

let
  quickshellQml = "${quickshell}/${qt6.qtbase.qtQmlPrefix}";
  qtQml = "${kdePackages.qtdeclarative}/${qt6.qtbase.qtQmlPrefix}";

  src = lib.fileset.toSource {
    root = ../src;
    fileset = lib.fileset.fileFilter (file: file.hasExt "qml") ../src;
  };

  nixFiles = lib.fileset.toSource {
    root = ../.;
    fileset = lib.fileset.fileFilter (file: file.hasExt "nix") ../.;
  };

  # Findings that are quickshell's type info being incomplete rather than
  # anything wrong with the shell, each matched by its category and the whole
  # of its message. Nothing here names a file of the shell's own: a finding
  # in the shell is fixed there, not excused here.
  excused = writeTextDir "excused.jq" ''
    def excused:
      # The type info only describes PanelWindow's interface, which is not
      # creatable; the window itself is registered under the same name by
      # the wayland or x11 plugin when quickshell starts.
      (.id == "uncreatable-type"
        and (.message | test("^Type PanelWindow is not creatable\\.$")))
      # Quickshell.Bluetooth's qmldir does not depend on Quickshell, and
      # its properties name their types without the namespace they are
      # registered under, so none of them resolve.
      or (.id == "unresolved-type"
        and (.message | test("^Type \"(BluetoothAdapter|UntypedObjectModel|BluetoothDeviceState::Enum)\" of property \"[A-Za-z]+\" not found\\.")))
      # Process's exited signal carries a QProcess enum no module exports.
      or (.id == "signal-handler-parameters"
        and (.message | test("^Type QProcess::ExitStatus of parameter exitStatus in signal called exited was not found")));
  '';
in
{
  # Quickshell makes every directory of the shell importable as qs.<dir>,
  # with a qmldir it writes as the shell starts. qmllint is given the same
  # thing ahead of time: the tree copied under qs/, and a qmldir in each
  # directory listing its types, the ones with `pragma Singleton` as
  # singletons, which is what quickshell's own say. The files are copies
  # rather than links, because qmllint follows a link back to the directory
  # it points into and looks for the qmldir there.
  #
  # Every category is left at qmllint's own level but one:
  # redundant-optional-chaining, which flags `?.` on a value the type info
  # says cannot be null — a guard against a pipewire node that has not
  # reported its properties yet is not a mistake. Unused imports stay at
  # info, as qmllint has them. Anything at warning or above fails the check
  # unless it is excused above.
  lint =
    runCommand "shell-lint"
      {
        LANG = "C.UTF-8";
        nativeBuildInputs = [
          kdePackages.qtdeclarative
          jq
        ];
      }
      ''
        mkdir -p imports/qs
        cp -r ${src}/. imports/qs
        chmod -R u+w imports
        cd imports

        find qs -type d | while read -r dir; do
          {
            echo "module ''${dir//\//.}"
            for file in "$dir"/*.qml; do
              name=$(basename "$file" .qml)
              [[ $name == [A-Z]* ]] || continue
              if grep -q '^pragma Singleton' "$file"; then
                echo "singleton $name 1.0 $name.qml"
              else
                echo "$name 1.0 $name.qml"
              fi
            done
          } > "$dir/qmldir"
        done

        find qs -name '*.qml' | sort > files
        echo "linting $(wc -l < files) files"

        qmllint --bare -I . -I ${quickshellQml} -I ${qtQml} \
          --redundant-optional-chaining info \
          --json report.json $(cat files) > /dev/null 2>&1 || true

        [ -s report.json ] || { echo "qmllint wrote no report"; exit 1; }

        jq -r -L ${excused} 'include "excused";
          .files[]
          | (.filename | sub("^qs/"; "src/")) as $file
          | .warnings[]
          | select(.type != "info")
          | select(excused | not)
          | "\($file):\(.line // 0):\(.column // 0): \(.message) [\(.id // .type)]"
        ' report.json > findings

        jq -r -L ${excused} 'include "excused";
          [.files[].warnings[] | select(.type != "info") | select(excused)] | length
        ' report.json > count

        if [ -s findings ]; then
          cat findings
          echo "qmllint: $(wc -l < findings) findings"
          exit 1
        fi

        echo "qmllint: clean, $(cat count) findings excused as quickshell's own"
        touch $out
      '';

  # The QML is checked against qmlformat with its defaults, which the tree
  # was already written in — every file but one, which was out by a single
  # indent; a file that is not is shown as the diff qmlformat would make, and
  # `qmlformat -i` in `nix develop` makes it. The nix files are checked
  # against nixfmt, the flake's formatter.
  format =
    runCommand "shell-format"
      {
        # Qt asks for a UTF-8 locale, once per file
        LANG = "C.UTF-8";
        nativeBuildInputs = [
          kdePackages.qtdeclarative
          nixfmt
        ];
      }
      ''
        status=0

        cd ${src}
        qml=$(find . -name '*.qml' | sort)
        for file in $qml; do
          if ! qmlformat "$file" | diff -u --label "src/''${file#./}" --label formatted "$file" -; then
            status=1
          fi
        done

        cd ${nixFiles}
        nix=$(find . -name '*.nix' | sort)
        nixfmt --check $nix || status=1

        if [ $status -ne 0 ]; then
          echo "not formatted: qmlformat -i <file> and nix fmt from nix develop"
          exit 1
        fi

        echo "formatted: $(wc -w <<< "$qml") qml files, $(wc -w <<< "$nix") nix files"
        touch $out
      '';

  # The sandbox has no fonts, and text with no font has no size, so the
  # layouts would be measured against nothing; one font is enough for every
  # row to take up room.
  smoke =
    runCommand "shell-smoke-run"
      {
        FONTCONFIG_FILE = makeFontsConf { fontDirectories = [ dejavu_fonts ]; };
        nativeBuildInputs = [ shell-smoke ];
      }
      ''
        shell-smoke
        touch $out
      '';
}
