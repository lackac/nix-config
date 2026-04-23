set -euo pipefail

xdg_config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
xdg_state_home="${XDG_STATE_HOME:-$HOME/.local/state}"

currency_file="${xdg_state_home}/units/currency.units"
key_file="${xdg_config_home}/units/openexchangerates-app-id"

mkdir -p "$(dirname "$currency_file")"

if [ -s "$key_file" ]; then
  key="$(tr -d '\n' < "$key_file")"
  exec units_cur --source openexchangerates --key "$key" "$currency_file"
fi

echo "units-refresh-currency: $key_file missing or empty; falling back to floatrates" >&2

exec units_cur --source floatrates "$currency_file"
