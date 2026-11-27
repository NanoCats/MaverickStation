import { CheckboxInput, type FeatureToggle } from '../../base';

export const maverick_arousal_overlay: FeatureToggle = {
  name: 'Arousal overlay',
  category: 'ERP',
  description: `
    Tints the edges of your screen pink when you are aroused. It gets
    stronger as arousal goes up.
  `,
  component: CheckboxInput,
};
