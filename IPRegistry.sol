// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IPRegistry
/// @notice On-chain registry that binds a project title and owner to a cryptographic document hash.
/// @dev The document hash is the lookup key. A later change to the file produces a different hash,
///      so a successful lookup is evidence that the registered fingerprint still matches.
contract IPRegistry {
    struct Project {
        string title;
        address owner;
        uint256 registeredAt;
        bool exists;
    }

    /// @dev Project record keyed by the 32-byte document hash (for example, SHA-256).
    mapping(bytes32 => Project) private projects;

    event ProjectRegistered(
        bytes32 indexed documentHash,
        string title,
        address indexed owner,
        uint256 timestamp
    );

    event OwnershipTransferred(
        bytes32 indexed documentHash,
        address indexed previousOwner,
        address indexed newOwner,
        uint256 timestamp
    );

    /// @notice Register a new project. The caller becomes the owner and the block timestamp is stored.
    /// @param title Human-readable project title.
    /// @param documentHash Cryptographic hash of the project document. Must be unique and non-zero.
    function registerProject(string calldata title, bytes32 documentHash) external {
        require(bytes(title).length > 0, "Title required");
        require(bytes(title).length <= 200, "Title too long");
        require(documentHash != bytes32(0), "Invalid document hash");
        require(!projects[documentHash].exists, "Hash already registered");

        projects[documentHash] = Project({
            title: title,
            owner: msg.sender,
            registeredAt: block.timestamp,
            exists: true
        });

        emit ProjectRegistered(documentHash, title, msg.sender, block.timestamp);
    }

    /// @notice Transfer a registered project to a new owner.
    /// @param documentHash Hash of the project to transfer.
    /// @param newOwner Address that should receive ownership.
    function transferOwnership(bytes32 documentHash, address newOwner) external {
        Project storage project = projects[documentHash];

        require(project.exists, "Project not found");
        require(msg.sender == project.owner, "Not the owner");
        require(newOwner != address(0), "Invalid new owner");
        require(newOwner != project.owner, "Already the owner");

        address previousOwner = project.owner;
        project.owner = newOwner;

        emit OwnershipTransferred(documentHash, previousOwner, newOwner, block.timestamp);
    }

    /// @notice Look up a document hash and return the registered title, owner, and timestamp.
    /// @dev Reverts when the hash was never registered, which is the negative case for integrity checks.
    function verifyDocument(bytes32 documentHash)
        external
        view
        returns (string memory title, address owner, uint256 timestamp)
    {
        require(documentHash != bytes32(0), "Invalid document hash");

        Project storage project = projects[documentHash];
        require(project.exists, "No record for this hash");

        return (project.title, project.owner, project.registeredAt);
    }

    /// @notice Returns true when a document hash already has a registry record.
    function isRegistered(bytes32 documentHash) external view returns (bool) {
        return projects[documentHash].exists;
    }
}
