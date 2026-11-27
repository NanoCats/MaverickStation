import {
  type Feature,
  FeatureColorInput,
  type FeatureNumeric,
  FeatureSliderInput,
} from '../../base';

export const bimbo_intensity: FeatureNumeric = {
  name: 'Bimbo intensity',
  component: FeatureSliderInput,
};

export const bimbo_lipstick_color: Feature<string> = {
  name: 'Lipstick color',
  component: FeatureColorInput,
};
