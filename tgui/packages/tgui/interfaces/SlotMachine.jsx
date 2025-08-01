import { AnimatedNumber, Box, Button, LabeledList, Section } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

export const SlotMachine = (props) => {
  const { act, data } = useBackend();
  if (data.money === null) {
    return (
      <Window width={350} height={90}>
        <Window.Content>
          <Section>
            <Box>Could not scan your card or could not find account!</Box>
            <Box>Please wear or hold your ID and try again.</Box>
          </Section>
        </Window.Content>
      </Window>
    );
  } else {
    let playerText;
    if (data.plays === 1) {
      playerText = data.plays + ' player has tried their luck today!';
    } else {
      playerText = data.plays + ' players have tried their luck today!';
    }
    return (
      <Window width={300} height={151}>
        <Window.Content>
          <Section>
            <Box lineHeight={2}>{playerText}</Box>
            <LabeledList>
              <LabeledList.Item label="Credits Remaining">
                <AnimatedNumber value={data.money} />
              </LabeledList.Item>
              <LabeledList.Item label="10 credits to spin">
                <Button
                  icon="coins"
                  disabled={data.working}
                  content={data.working ? 'Spinning...' : 'Spin'}
                  onClick={() => act('spin')}
                />
              </LabeledList.Item>
            </LabeledList>
            <Box bold lineHeight={2} color={data.resultlvl}>
              {data.result}
            </Box>
          </Section>
        </Window.Content>
      </Window>
    );
  }
};
