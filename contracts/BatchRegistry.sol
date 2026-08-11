// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract BatchRegistry {
    // ----------------------------
    // Types
    // ----------------------------

    enum QualityStatus { Pending, Approved, Rejected }

    struct Batch {
        uint256 id;
        string productName;
        uint256 weightGrams;
        uint256 productionDate; // unix timestamp
        address producer;
        QualityStatus status;
        address currentOwner;
        bool exists;
    }

    // ----------------------------
    // State
    // ----------------------------

    address public owner;

    mapping(address => bool) public producers;
    mapping(address => bool) public inspectors;
    mapping(uint256 => Batch) public batches;

    uint256 private nextBatchId = 1;

    // ----------------------------
    // Events
    // ----------------------------

    event BatchCreated(uint256 indexed batchId, address indexed producer, string productName);
    event BatchTransferred(uint256 indexed batchId, address indexed from, address indexed to);
    event BatchApproved(uint256 indexed batchId, address indexed inspector, QualityStatus status);
    event ProducerUpdated(address indexed account, bool isProducer);
    event InspectorUpdated(address indexed account, bool isInspector);

    // ----------------------------
    // Modifiers
    // ----------------------------

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    modifier onlyProducer() {
        require(producers[msg.sender], "Not a registered producer");
        _;
    }

    modifier onlyInspector() {
        require(inspectors[msg.sender], "Not a registered inspector");
        _;
    }

    modifier batchExists(uint256 batchId) {
        require(batches[batchId].exists, "Batch does not exist");
        _;
    }

    // ----------------------------
    // Constructor
    // ----------------------------

    constructor() {
        owner = msg.sender;
        producers[msg.sender] = true;
        inspectors[msg.sender] = true;
    }

    // ----------------------------
    // Admin functions
    // ----------------------------

    function setProducer(address account, bool isProducer) external onlyOwner {
        producers[account] = isProducer;
        emit ProducerUpdated(account, isProducer);
    }

    function setInspector(address account, bool isInspector) external onlyOwner {
        inspectors[account] = isInspector;
        emit InspectorUpdated(account, isInspector);
    }

    // ----------------------------
    // Core functions
    // ----------------------------

    function createBatch(
        string calldata productName,
        uint256 weightGrams,
        uint256 productionDate
    ) external onlyProducer returns (uint256) {
        require(weightGrams > 0, "Weight must be positive");
        require(bytes(productName).length > 0, "Product name required");

        uint256 batchId = nextBatchId++;

        batches[batchId] = Batch({
            id: batchId,
            productName: productName,
            weightGrams: weightGrams,
            productionDate: productionDate,
            producer: msg.sender,
            status: QualityStatus.Pending,
            currentOwner: msg.sender,
            exists: true
        });

        emit BatchCreated(batchId, msg.sender, productName);
        return batchId;
    }

    function transferBatch(uint256 batchId, address newOwner)
        external
        batchExists(batchId)
    {
        Batch storage batch = batches[batchId];
        require(msg.sender == batch.currentOwner, "Not the current owner");
        require(newOwner != address(0), "Invalid new owner");

        address previousOwner = batch.currentOwner;
        batch.currentOwner = newOwner;

        emit BatchTransferred(batchId, previousOwner, newOwner);
    }

    function approveBatch(uint256 batchId, bool approved)
        external
        onlyInspector
        batchExists(batchId)
    {
        Batch storage batch = batches[batchId];
        batch.status = approved ? QualityStatus.Approved : QualityStatus.Rejected;

        emit BatchApproved(batchId, msg.sender, batch.status);
    }

    // ----------------------------
    // View functions
    // ----------------------------

    function getBatch(uint256 batchId)
        external
        view
        batchExists(batchId)
        returns (
            uint256 id,
            string memory productName,
            uint256 weightGrams,
            uint256 productionDate,
            address producer,
            QualityStatus status,
            address currentOwner
        )
    {
        Batch storage batch = batches[batchId];
        return (
            batch.id,
            batch.productName,
            batch.weightGrams,
            batch.productionDate,
            batch.producer,
            batch.status,
            batch.currentOwner
        );
    }

    function verifyBatch(uint256 batchId)
        external
        view
        batchExists(batchId)
        returns (bool isApproved)
    {
        return batches[batchId].status == QualityStatus.Approved;
    }
}
