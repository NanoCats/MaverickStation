import { useState } from 'react';
import {
  Box,
  Button,
  Dropdown,
  NoticeBox,
  Section,
  Stack,
} from 'tgui-core/components';
import { useBackend } from '../backend';
import { Window } from '../layouts';

type Data = {
  ask_age: boolean;
  policy_text: string;
  current_year: number;
  current_month: number;
  current_day: number;
  max_age: number;
};

const MONTHS = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/** Days in a month. Month is 1 to 12. */
function daysInMonth(year: number, month: number): number {
  return new Date(year, month, 0).getDate();
}

/**
 * Works out the age from the date of birth against the server's date.
 * Only the age goes to the server, so the date of birth is never logged.
 */
function ageOn(year: number, month: number, day: number, data: Data): number {
  let age = data.current_year - year;
  if (
    data.current_month < month ||
    (data.current_month === month && data.current_day < day)
  ) {
    age--;
  }
  return age;
}

export const AgeGate = (props) => {
  const { act, data } = useBackend<Data>();
  const [year, setYear] = useState<number>();
  const [month, setMonth] = useState<number>();
  const [day, setDay] = useState<number>();

  const yearOptions: string[] = [];
  for (let y = data.current_year; y >= data.current_year - data.max_age; y--) {
    yearOptions.push(String(y));
  }
  const dayCount = year && month ? daysInMonth(year, month) : 31;
  const dayOptions: string[] = [];
  for (let d = 1; d <= dayCount; d++) {
    dayOptions.push(String(d));
  }

  const dayValid = !!day && day <= dayCount;
  const age = year && month && dayValid ? ageOn(year, month, day, data) : null;
  const dateValid = age !== null && age >= 0 && age <= data.max_age;
  const canSubmit = !data.ask_age || dateValid;

  return (
    <Window width={560} height={data.ask_age ? 640 : 560} title="Welcome">
      <Window.Content>
        <Stack vertical fill>
          <Stack.Item>
            <Box>
              {data.ask_age
                ? 'This server is for adults only, and we keep as little of your data as we can. Read what we collect, then enter your date of birth.'
                : 'Our privacy policy has changed. Please read it and agree to continue.'}
            </Box>
          </Stack.Item>
          <Stack.Item grow>
            <Section fill scrollable title="Privacy policy">
              <Box style={{ whiteSpace: 'pre-wrap' }}>{data.policy_text}</Box>
            </Section>
          </Stack.Item>
          {data.ask_age && (
            <Stack.Item>
              <Section title="Date of birth">
                <Stack>
                  <Stack.Item grow>
                    <Dropdown
                      width="100%"
                      placeholder="Month"
                      selected={month ? MONTHS[month - 1] : null}
                      options={MONTHS}
                      onSelected={(value) =>
                        setMonth(MONTHS.indexOf(value) + 1)
                      }
                    />
                  </Stack.Item>
                  <Stack.Item>
                    <Dropdown
                      width="70px"
                      placeholder="Day"
                      selected={dayValid ? String(day) : null}
                      options={dayOptions}
                      onSelected={(value) => setDay(Number(value))}
                    />
                  </Stack.Item>
                  <Stack.Item>
                    <Dropdown
                      width="90px"
                      placeholder="Year"
                      selected={year ? String(year) : null}
                      options={yearOptions}
                      onSelected={(value) => setYear(Number(value))}
                    />
                  </Stack.Item>
                </Stack>
                {age !== null && !dateValid && (
                  <NoticeBox danger mt={1} mb={0}>
                    That date is not valid.
                  </NoticeBox>
                )}
                <Box mt={1} color="label">
                  We only keep whether you passed. Your date of birth never
                  leaves your computer.
                </Box>
              </Section>
            </Stack.Item>
          )}
          <Stack.Item>
            <Button
              fluid
              textAlign="center"
              color="good"
              disabled={!canSubmit}
              onClick={() => act('submit', data.ask_age ? { age } : {})}
            >
              Agree and continue
            </Button>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
