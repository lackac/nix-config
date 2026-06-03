{ self, ... }:
{
  flake.templates = {
    elixir = {
      path = ../templates/elixir;
      description = "Minimal Elixir development shell";
    };

    phoenix = {
      path = ../templates/phoenix;
      description = "Minimal Phoenix development shell";
    };

    default = self.templates.elixir;
  };
}
