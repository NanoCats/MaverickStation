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
  shots: number;
  hair_mode: string;
  hair_color: string;
  lipstick_color: string | null;
  hair_modes: string[];
};

const CUSTOM = 'Custom color';

export const ThotAccelerator = () => {
  const { act, data } = useBackend<Data>();
  const { charge, shots, hair_mode, hair_color, lipstick_color, hair_modes } =
    data;
  return (
    <Window title="LustWish THOT Accelerator" width={400} height={240}>
      <Window.Content>
        <Section>
          <LabeledList>
            <LabeledList.Item label="Charge">
              <ProgressBar value={charge / 100} color="pink">
                {shots} shots
              </ProgressBar>
            </LabeledList.Item>
          </LabeledList>
        </Section>
        <Section title="Makeover">
          <LabeledList>
            <LabeledList.Item label="Hair">
              {hair_modes.map((mode) => (
                <Button
                  key={mode}
                  selected={hair_mode === mode}
                  icon={mode === CUSTOM ? 'palette' : undefined}
                  tooltip={mode === CUSTOM ? 'Pick a color' : undefined}
                  onClick={() => act('set_hair_mode', { mode })}
                >
                  {mode === CUSTOM ? (
                    <>
                      Custom <ColorBox color={hair_color} ml={0.5} />
                    </>
                  ) : (
                    mode
                  )}
                </Button>
              ))}
            </LabeledList.Item>
            <LabeledList.Item label="Lipstick">
              <Button
                selected={!lipstick_color}
                onClick={() => act('reset_lipstick')}
              >
                Their own
              </Button>
              <Button
                icon="palette"
                selected={!!lipstick_color}
                onClick={() => act('pick_lipstick')}
              >
                Custom{' '}
                {!!lipstick_color && (
                  <ColorBox color={lipstick_color} ml={0.5} />
                )}
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
