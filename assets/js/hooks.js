import CreateSecret from "./hooks/createSecret";
import DecryptSecret from "./hooks/decryptSecret";
import ShowPassphraseAfterCreate from "./hooks/showPassphraseAfterCreate";
import OnIncorrectPassphrase from "./hooks/onIncorrectPassphrase";
import ComputeTimestampAgo from "./hooks/computeTimestampAgo";

let Hooks = {
  CreateSecret: CreateSecret,
  DecryptSecret: DecryptSecret,
  ShowPassphraseAfterCreate: ShowPassphraseAfterCreate,
  OnIncorrectPassphrase: OnIncorrectPassphrase,
  ComputeTimestampAgo: ComputeTimestampAgo,
};

export default Hooks;
