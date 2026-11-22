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
