import { Box } from 'tgui-core/components';

/**
 * Placeholder antagonist rules, shown in the antag info panels.
 * There is no wiki to link to, so the rules live here for now.
 * Leadership will replace these with the real rules later.
 */
export const MaverickAntagRules = () => (
  <Box>
    <Box italic color="label" mb={0.5}>
      Placeholder rules. These will change.
    </Box>
    <ul style={{ margin: 0, paddingLeft: '1.5em' }}>
      <li>Your job is to make the round interesting, not to win at any cost.</li>
      <li>Match your response to the threat. Escalate slowly.</li>
      <li>
        Do not destroy the station or kill large numbers of crew unless your
        objectives need it.
      </li>
      <li>Leave disconnected and AFK players alone.</li>
      <li>Respect the content preferences other players have set.</li>
      <li>If you are not sure something is allowed, ask the admins first.</li>
    </ul>
  </Box>
);

/**
 * Rules for MaxTac operatives. MaxTac is the last answer before a death squad:
 * someone pushed the station too far, and the team is here to end it.
 */
export const MaxTacRules = () => (
  <Box>
    <ul style={{ margin: 0, paddingLeft: '1.5em' }}>
      <li>
        You are here because someone went too far. Find your target and put
        them down. You do not need to warn, arrest or negotiate.
      </li>
      <li>
        Lethal force is authorized against your target and anyone who fights
        for them or gets in your way.
      </li>
      <li>
        Crew who stay out of the fight are not your targets. You are one step
        below a death squad, not a death squad.
      </li>
      <li>
        Property damage that comes with the job is fine. Do not gut the station
        for no reason.
      </li>
      <li>When the target is down, report in and leave.</li>
      <li>Respect the content preferences other players have set.</li>
    </ul>
  </Box>
);
