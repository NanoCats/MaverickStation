import {
  Box,
  Button,
  ColorBox,
  LabeledList,
  ProgressBar,
  Section,
} from 'tgui-core/components';
import { useBackend } from '../backend';
import { Window } from '../layouts';

type Data = {
  charge: number;
  makeover: boolean;
  wardrobe: boolean;
  hair_mode: string;
  hair_color: string;
  hair_modes: string[];
};

export const ThotAccelerator = () => {
  const { act, data } = useBackend<Data>();
  const { charge, makeover, wardrobe, hair_mode, hair_color, hair_modes } =
    data;
  return (
    <Window title="LustWish THOT Accelerator" width={360} height={290}>
      <Window.Content>
        <Section>
          <LabeledList>
            <LabeledList.Item label="Charge">
              <ProgressBar value={charge / 100} color="pink">
                {charge}%
              </ProgressBar>
            </LabeledList.Item>
          </LabeledList>
        </Section>
        <Section title="Pulse Settings">
          <LabeledList>
            <LabeledList.Item label="Makeover">
              <Button
                icon={makeover ? 'heart' : 'times'}
                selected={makeover}
                tooltip="Hair, figure and breasts change step by step."
                onClick={() => act('toggle_makeover')}
              >
                {makeover ? 'On' : 'Off'}
              </Button>
            </LabeledList.Item>
            <LabeledList.Item label="Wardrobe">
              <Button
                icon={wardrobe ? 'shirt' : 'times'}
                selected={wardrobe}
                tooltip="An overdose turns clothes, shoes and ID card slutty."
                onClick={() => act('toggle_wardrobe')}
              >
                {wardrobe ? 'On' : 'Off'}
              </Button>
            </LabeledList.Item>
            <LabeledList.Item label="Hair">
              {hair_modes.map((mode) => (
                <Button
                  key={mode}
                  selected={hair_mode === mode}
                  disabled={!makeover}
                  onClick={() => act('set_hair_mode', { mode })}
                >
                  {mode}
                </Button>
              ))}
            </LabeledList.Item>
            <LabeledList.Item label="Hair Color">
              <ColorBox color={hair_color} mr={1} />
              <Button
                icon="palette"
                disabled={!makeover}
                onClick={() => act('pick_hair_color')}
              >
                Pick
              </Button>
            </LabeledList.Item>
          </LabeledList>
        </Section>
        <Box italic color="label" textAlign="center">
          Proprietary bimbofication technology. Point away from face.
        </Box>
      </Window.Content>
    </Window>
  );
};
