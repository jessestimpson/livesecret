import ShowPassphraseAfterCreate from "./hooks/showPassphraseAfterCreate";
import SubmitDecrypt from "./hooks/submitDecrypt";
import OnIncorrectPassphrase from "./hooks/onIncorrectPassphrase";

let Hooks = {
  ShowPassphraseAfterCreate: ShowPassphraseAfterCreate,
  SubmitDecrypt: SubmitDecrypt,
  OnIncorrectPassphrase: OnIncorrectPassphrase,
};

export default Hooks;
