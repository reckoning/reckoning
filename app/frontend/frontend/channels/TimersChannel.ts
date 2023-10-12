import { Channel } from "@anycable/web";
import type { Timer } from "@/frontend/api/client/models/Timer";

type Params = {
  room: string;
};

type Message = Timer;

export default class TimersChannel extends Channel<Params, Message> {
  static identifier = "TimersChannel";

  receive(data: Message) {
    const timer = JSON.parse(String(data)) as Timer;

    super.receive(timer);
  }
}
