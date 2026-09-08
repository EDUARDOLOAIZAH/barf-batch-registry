import { expect } from "chai";
import { network } from "hardhat";

describe("BatchRegistry", function () {
  async function deployFixture() {
    const { ethers } = await network.getOrCreate();
    const [owner, producer, inspector, buyer, stranger] = await ethers.getSigners();

    const BatchRegistry = await ethers.getContractFactory("BatchRegistry");
    const registry = await BatchRegistry.deploy();

    // Register a producer and inspector distinct from the owner
    await registry.setProducer(producer.address, true);
    await registry.setInspector(inspector.address, true);

    return { registry, owner, producer, inspector, buyer, stranger };
  }

  it("sets the deployer as owner, producer, and inspector", async function () {
    const { registry, owner } = await deployFixture();
    expect(await registry.owner()).to.equal(owner.address);
    expect(await registry.producers(owner.address)).to.equal(true);
    expect(await registry.inspectors(owner.address)).to.equal(true);
  });

  it("allows a registered producer to create a batch", async function () {
    const { registry, producer } = await deployFixture();

    const tx = await registry
      .connect(producer)
      .createBatch("Chicken & Veggie Mix", 5000, 1234567890);

    await expect(tx)
      .to.emit(registry, "BatchCreated")
      .withArgs(1n, producer.address, "Chicken & Veggie Mix");

    const batch = await registry.getBatch(1);
    expect(batch.productName).to.equal("Chicken & Veggie Mix");
    expect(batch.currentOwner).to.equal(producer.address);
  });

  it("reverts if a non-producer tries to create a batch", async function () {
    const { registry, stranger } = await deployFixture();

    await expect(
      registry.connect(stranger).createBatch("Fake Batch", 1000, 123)
    ).to.be.revertedWith("Not a registered producer");
  });

  it("allows the current owner to transfer a batch", async function () {
    const { registry, producer, buyer } = await deployFixture();

    await registry.connect(producer).createBatch("Beef Blend", 3000, 111);
    await registry.connect(producer).transferBatch(1, buyer.address);

    const batch = await registry.getBatch(1);
    expect(batch.currentOwner).to.equal(buyer.address);
  });

  it("reverts if someone other than the current owner tries to transfer", async function () {
    const { registry, producer, stranger, buyer } = await deployFixture();

    await registry.connect(producer).createBatch("Beef Blend", 3000, 111);

    await expect(
      registry.connect(stranger).transferBatch(1, buyer.address)
    ).to.be.revertedWith("Not the current owner");
  });

  it("allows an inspector to approve a batch", async function () {
    const { registry, producer, inspector } = await deployFixture();

    await registry.connect(producer).createBatch("Turkey Mix", 2000, 111);
    await registry.connect(inspector).approveBatch(1, true);

    const isApproved = await registry.verifyBatch(1);
    expect(isApproved).to.equal(true);
  });

  it("reverts if a non-inspector tries to approve a batch", async function () {
    const { registry, producer, stranger } = await deployFixture();

    await registry.connect(producer).createBatch("Turkey Mix", 2000, 111);

    await expect(
      registry.connect(stranger).approveBatch(1, true)
    ).to.be.revertedWith("Not a registered inspector");
  });

  it("reverts when querying a batch that doesn't exist", async function () {
    const { registry } = await deployFixture();

    await expect(registry.getBatch(999)).to.be.revertedWith(
      "Batch does not exist"
    );
  });
});
