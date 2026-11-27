import { CheckboxInput, type FeatureToggle } from '../../base';

export const maverick_lobby_shuffle: FeatureToggle = {
  name: 'Shuffle lobby music',
  category: 'SOUND',
  description: `
    SpaceAmp plays the lobby playlist in random order, and skips the last few
    songs it played. Same as the SHUF button in SpaceAmp.
  `,
  component: CheckboxInput,
};
