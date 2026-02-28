{ lib, ... }:
{
  flake.modules.homeManager.starship =
    { ... }:
    {
      programs.starship = {
        enable = true;
        enableBashIntegration = true;
        enableZshIntegration = true;
        enableNushellIntegration = true;

        settings = {
          format = lib.concatStrings [
            "$username"
            "$hostname"
            "$directory"
            "$git_branch"
            "$git_state"
            "$git_status"
            "$elixir"
            "$ruby"
            "$python"
            "$nodejs"
            "$cmd_duration"
            "$line_break"
            "$character"
          ];

          directory = {
            style = "blue";
            read_only = " 󰌾";
            truncation_length = 5;
            truncate_to_repo = false;
            truncation_symbol = "…/";
          };

          directory.substitutions = {
            "~/Library/CloudStorage/GoogleDrive-lackac@gmail.com/My Drive" = "GDrive";
            "~/Library/CloudStorage/GoogleDrive-laszlo.bacsi@100starlings.com/My Drive" = "GDrive-100S";
            "~/Code" = "Code";
          };

          cmd_duration = {
            format = "[󱎫 $duration]($style) ";
            style = "yellow";
          };

          character = {
            success_symbol = "[❯](green)";
            error_symbol = "[❯](red)";
            vimcmd_symbol = "[❮](blue)";
          };

          git_branch = {
            symbol = " ";
            format = "[$symbol$branch]($style)";
            style = "dim-yellow";
          };

          git_status = {
            format = "[[(*$conflicted$untracked$modified$staged$renamed$deleted)](dim-yellow) ($ahead_behind$stashed)]($style)";
            style = "cyan";
            conflicted = "  ";
            deleted = " 󰗨";
            modified = "  ";
            stashed = "  ";
            staged = "  ";
            renamed = "  ";
            untracked = "  ";
          };

          git_state = {
            format = "\([$state( $progress_current/$progress_total)]($style)\) ";
            style = "bright-black";
          };

          aws.symbol = "  ";

          elixir = {
            symbol = " ";
            format = "[$symbol($version \(OTP $otp_version\) )]($style)";
          };

          lua = {
            symbol = " ";
            format = "[$symbol($version )]($style)";
          };

          nodejs = {
            disabled = true;
            symbol = " ";
            format = "[$symbol($version )]($style)";
          };

          python = {
            style = "bright-black";
            format = "[$\{symbol\}$\{pyenv_prefix\}($\{version\} )(\($\{virtualenv\}\) )]($style)";
          };

          ruby = {
            symbol = " ";
            format = "[$symbol($version )]($style)";
          };

          package = {
            symbol = "󰏗 ";
            format = "[$symbol$version ]($style)";
          };

          os.symbols = {
            Alpine = " ";
            Amazon = " ";
            Arch = " ";
            CentOS = " ";
            Debian = " ";
            Linux = " ";
            Macos = " ";
            NixOS = " ";
            Raspbian = " ";
            Ubuntu = " ";
            Windows = "󰍲 ";
          };
        };
      };
    };
}
