import { CheckboxInput, type FeatureToggle } from '../../base';

export const object_tf_pref: FeatureToggle = {
  name: 'Object transformation',
  category: 'ERP',
  description: `
    Lets the LustWish TF toolgun turn you into an object. You can still hear,
    see and talk. The OOC Safe Word verb always lets you out.
  `,
  component: CheckboxInput,
};
