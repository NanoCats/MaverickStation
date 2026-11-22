import type { FeatureChoiced } from '../../base';
import { FeatureDropdownInput } from '../../dropdowns';

export const maverick_desktop_sounds: FeatureChoiced = {
  name: 'Lobby desktop sounds',
  category: 'SOUND',
  description: `
    Sounds on the lobby desktop. "All" plays the startup sound once per round,
    the shutdown sound, clicks and error chimes. "Clicks only" skips startup
    and shutdown. They follow the lobby music volume.
  `,
  component: FeatureDropdownInput,
};
