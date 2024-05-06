// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./DAOToken.sol";
import "./Governance.sol";
import "./Administrative.sol";

contract YourDAO is Ownable {
    DAOToken public daoToken;
    Governance public governance;
    Administrative public administrative;

    mapping(address => uint256) private _governancePoints;
    mapping(address => bool) private _members;

    uint256 public constant GOVERNANCE_POINT_PRICE = 740000000000000; // 0.00074 ETH in wei

    event GovernancePointsAdded(address indexed account, uint256 amount);
    event GovernancePointsSubtracted(address indexed account, uint256 amount);
    event MemberAdded(address indexed account);
    event MemberRemoved(address indexed account);

    // Adjusted constructor with initialOwner parameter
    constructor(address initialOwner, DAOToken _daoToken, Governance _governance, Administrative _administrative)
        Ownable(initialOwner)  // Pass initialOwner to the Ownable constructor
    {
        daoToken = _daoToken;
        governance = _governance;
        administrative = _administrative;
    }

    function addGovernancePoints(address account, uint256 amount) external onlyOwner {
        _governancePoints[account] += amount;
        emit GovernancePointsAdded(account, amount);
    }

    function subtractGovernancePoints(address account, uint256 amount) external onlyOwner {
        require(_governancePoints[account] >= amount, "Insufficient points");
        _governancePoints[account] -= amount;
        emit GovernancePointsSubtracted(account, amount);
    }

    function getGovernancePoints(address account) external view returns (uint256) {
        return _governancePoints[account];
    }

    function addMember(address account) external onlyOwner {
        require(!_members[account], "Already a member");
        _members[account] = true;
        emit MemberAdded(account);
    }

    function removeMember(address account) external onlyOwner {
        require(_members[account], "Not a member");
        _members[account] = false;
        emit MemberRemoved(account);
    }

    function isMember(address account) external view returns (bool) {
        return _members[account];
    }

    function buyGovernancePoints() public payable {
        uint256 numberOfPoints = msg.value / GOVERNANCE_POINT_PRICE;
        require(numberOfPoints > 0, "Not enough ETH sent");

        uint256 cost = numberOfPoints * GOVERNANCE_POINT_PRICE;
        if (msg.value > cost) {
            // Refund the excess amount
            payable(msg.sender).transfer(msg.value - cost);
        }

        _governancePoints[msg.sender] += numberOfPoints;
        emit GovernancePointsAdded(msg.sender, numberOfPoints);
    }

    // Example of interacting with Governance
    function createProposal(string memory description, uint256 amount, address payable recipient) public {
        governance.createProposal(description, amount, recipient);
    }

    // Delegate call to administrative functions
    function delegate(address delegatee) public {
        administrative.delegate(delegatee);
    }

    function undelegate() public {
        administrative.undelegate();
    }
}
