import ShowPassphraseAfterCreate from "./hooks/showPassphraseAfterCreate";
import SubmitDecrypt from "./hooks/submitDecrypt";
import OnIncorrectPassphrase from "./hooks/onIncorrectPassphrase";
import ComputeTimestampAgo from "./hooks/computeTimestampAgo";

let Hooks = {
  ShowPassphraseAfterCreate: ShowPassphraseAfterCreate,
  SubmitDecrypt: SubmitDecrypt,
  OnIncorrectPassphrase: OnIncorrectPassphrase,
  ComputeTimestampAgo: ComputeTimestampAgo,
};

export default Hooks;
