{ ... }:
{
  flake.modules.homeManager.package-runners =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        nodejs
        pnpm
        uv
      ];

      home.file.".npmrc".text = ''
        # Supply-chain policy: avoid brand-new package versions and lifecycle hooks by default.
        # Prefer pnpm dlx for Node package runners; use npx/npm exec only for compatibility.
        # Trusted one-off override: npm exec --ignore-scripts=false --min-release-age=0 -- <pkg>
        ignore-scripts=true
        min-release-age=7
      '';

      xdg.configFile."pnpm/rc".text = ''
        # Supply-chain policy: delay brand-new package versions and require explicit trust for builds.
        # Trusted age-gate override: pnpm dlx --config.minimum-release-age=0 <pkg>
        # Trusted build override: pnpm approve-builds, or set allowBuilds in pnpm-workspace.yaml.
        minimum-release-age=10080
        strict-dep-builds=true
        dangerously-allow-all-builds=false
      '';

      xdg.configFile."uv/uv.toml".text = ''
        # Supply-chain policy: avoid brand-new distributions and source builds by default.
        # Trusted age-gate override: uvx --exclude-newer now <pkg>
        # Trusted source-build override: uvx --no-config --exclude-newer 7d <pkg>
        exclude-newer = "7d"
        no-build = true
      '';
    };
}
