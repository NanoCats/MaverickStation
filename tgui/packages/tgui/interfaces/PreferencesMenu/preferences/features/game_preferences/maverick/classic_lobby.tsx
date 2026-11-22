import { CheckboxInput, type FeatureToggle } from '../../base';

export const maverick_classic_lobby: FeatureToggle = {
  name: 'Classic lobby',
  category: 'UI',
  description: `
    Show a plain lobby menu instead of the desktop.
  `,
  component: CheckboxInput,
};
