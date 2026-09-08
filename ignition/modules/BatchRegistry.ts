import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("BatchRegistryModule", (m) => {
  const batchRegistry = m.contract("BatchRegistry");

  return { batchRegistry };
});
