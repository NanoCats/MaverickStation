import type { FeatureChoiced } from '../../base';
import { FeatureDropdownInput } from '../../dropdowns';

export const maverick_trait_gear: FeatureChoiced = {
  name: 'Station trait gear',
  category: 'GAMEPLAY',
  description: `
    What to do with gear that station traits hand out when you spawn: party
    hats, wallets and scryers. "Put it in my bag" leaves your own outfit alone.
  `,
  component: FeatureDropdownInput,
};
