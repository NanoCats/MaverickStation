import {
  CheckboxInput,
  type Feature,
  FeatureColorInput,
  type FeatureToggle,
} from '../../base';

export const pointer_color_toggle: FeatureToggle = {
  name: 'Pointer Color',
  description:
    'Give the arrow you point with a color of your choice. A Kommand skillchip starts with this color, and you can still change it in the round.',
  component: CheckboxInput,
};

export const pointer_color: Feature<string> = {
  name: 'Pointer Color Choice',
  description: 'The color of the arrow when you point at something.',
  component: FeatureColorInput,
};
