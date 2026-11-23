import { useBackend } from '../backend';
import { Window } from '../layouts';

type Cheat = {
  key: string;
  name: string;
  address: string;
  type: string;
  value: string;
  active: boolean;
  waiting: boolean;
};

type Data = {
  cheats: Cheat[];
  round_started: boolean;
};

// Plain grey desktop-app look, like the cheat tools this is a joke about
const FACE = '#f0f0f0';
const SHADOW = '#a0a0a0';
const HILITE = '#ffffff';
const FONT = 'Tahoma, "Segoe UI", sans-serif';

const sunken = {
  borderTop: `1px solid ${SHADOW}`,
  borderLeft: `1px solid ${SHADOW}`,
  borderBottom: `1px solid ${HILITE}`,
  borderRight: `1px solid ${HILITE}`,
  background: '#ffffff',
};

const cell = {
  padding: '2px 6px',
  borderRight: '1px solid #e0e0e0',
  whiteSpace: 'nowrap' as const,
};

const headCell = {
  ...cell,
  background: FACE,
  borderBottom: `1px solid ${SHADOW}`,
  textAlign: 'left' as const,
  fontWeight: 'normal' as const,
};

function CheckBox(props: { checked: boolean; onClick: () => void }) {
  const { checked, onClick } = props;
  return (
    <span
      onClick={onClick}
      style={{
        display: 'inline-block',
        width: '13px',
        height: '13px',
        lineHeight: '11px',
        textAlign: 'center',
        fontSize: '11px',
        cursor: 'pointer',
        ...sunken,
      }}
    >
      {checked ? '✔' : ''}
    </span>
  );
}

export const MaverickCheatEngine = () => {
  const { act, data } = useBackend<Data>();
  const { cheats, round_started } = data;
  const allOn = cheats.every((cheat) => cheat.active);

  return (
    <Window width={620} height={330} title="Cheat Engine 13.0">
      <Window.Content
        style={{
          background: FACE,
          color: '#000000',
          fontFamily: FONT,
          fontSize: '12px',
          padding: '8px',
        }}
      >
        <div style={{ ...sunken, padding: '4px 6px', marginBottom: '8px' }}>
          Process: 00001337-dreamseeker.exe (Space Station 13)
          <span style={{ float: 'right', color: '#606060' }}>
            {round_started ? 'Round in progress' : 'In the lobby'}
          </span>
        </div>
        <div style={{ ...sunken, height: '200px', overflowY: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr>
                <th style={headCell}>Active</th>
                <th style={headCell}>Description</th>
                <th style={headCell}>Address</th>
                <th style={headCell}>Type</th>
                <th style={headCell}>Value</th>
              </tr>
            </thead>
            <tbody>
              {cheats.map((cheat) => (
                <tr
                  key={cheat.key}
                  style={{ background: cheat.active ? '#cce8ff' : undefined }}
                >
                  <td style={{ ...cell, textAlign: 'center' }}>
                    <CheckBox
                      checked={cheat.active}
                      onClick={() => act('toggle', { key: cheat.key })}
                    />
                  </td>
                  <td style={cell}>
                    {cheat.name}
                    {cheat.waiting ? (
                      <span style={{ color: '#606060' }}>
                        {' '}
                        (applies at round start)
                      </span>
                    ) : null}
                  </td>
                  <td style={{ ...cell, fontFamily: 'monospace' }}>
                    {cheat.address}
                  </td>
                  <td style={cell}>{cheat.type}</td>
                  <td style={cell}>{cheat.value}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <div style={{ marginTop: '8px' }}>
          <label style={{ cursor: 'pointer' }}>
            <CheckBox checked={allOn} onClick={() => act('toggle_all')} />{' '}
            <span onClick={() => act('toggle_all')}>Activate all</span>
          </label>
          <span style={{ float: 'right', color: '#606060' }}>
            Turning a cheat off takes back what it added.
          </span>
        </div>
      </Window.Content>
    </Window>
  );
};
