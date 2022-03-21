always @(tb.uut.state or tb.uut.next_state)
begin
  case (tb.uut.state)
      Zero: current_state = "Zero";
      one : current_state = "one ";
      two : current_state = "two ";
      thre: current_state = "thre";
      four: current_state = "four";
      default:current_state = "Error";
  endcase
  case (tb.uut.next_state)
      Zero: next_state = "Zero";
      one : next_state = "one ";
      two : next_state = "two ";
      thre: next_state = "thre";
      four: next_state = "four";
      default:next_state = "Error";
  endcase
end
