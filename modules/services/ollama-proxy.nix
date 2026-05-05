{ ... }:
{
  flake.modules.darwin.ollama-tailnet-proxy =
    { ... }:
    {
      environment.etc."caddy/local.d/ollama.caddy".text = ''
        ai.lackac.hu {
          tls {
            dns dnsimple {$DNSIMPLE_API_ACCESS_TOKEN}
          }

          @tailnet remote_ip 100.64.0.0/10

          handle @tailnet {
            reverse_proxy 127.0.0.1:11434 {
              header_up Host localhost:11434
            }
          }

          handle {
            respond 403
          }
        }
      '';
    };
}
