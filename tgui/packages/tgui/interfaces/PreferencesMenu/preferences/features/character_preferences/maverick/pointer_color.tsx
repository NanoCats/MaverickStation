import {
  CheckboxInput,
  type Feature,
  FeatureColorInput,
  type FeatureToggle,
} from '../../base';

export const pointer_color_toggle: FeatureToggle = {
  name: 'Custom Pointer Color',
  description: 'Give the arrow you point with a color of your choice.',
  component: CheckboxInput,
};

export const pointer_color: Feature<string> = {
  name: 'Pointer Color',
  description: 'The color of the arrow when you point at something.',
  component: FeatureColorInput,
};
