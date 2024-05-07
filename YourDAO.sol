// SPDX-License-Identifier: MIT
// captchaDAO implementation

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

    constructor(address initialOwner, DAOToken _daoToken, Governance _governance, Administrative _administrative)
        Ownable(initialOwner)
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
        require(msg.value >= GOVERNANCE_POINT_PRICE, "Not enough ETH sent");
        uint256 numberOfPoints = msg.value / GOVERNANCE_POINT_PRICE;
        _governancePoints[msg.sender] += numberOfPoints;
        emit GovernancePointsAdded(msg.sender, numberOfPoints);

        // Refund any excess ETH sent
        uint256 excess = msg.value % GOVERNANCE_POINT_PRICE;
        if (excess > 0) {
            payable(msg.sender).transfer(excess);
        }
    }

    // Additional helper to receive ETH without buying points
    receive() external payable {
        // Call the buyGovernancePoints function when ETH is sent directly to the contract
        buyGovernancePoints();
    }

    function createProposal(string memory description, uint256 amount, address payable recipient) public {
        governance.createProposal(description, amount, recipient);
    }

    function delegate(address delegatee) public {
        administrative.delegate(delegatee);
    }

    function undelegate() public {
        administrative.undelegate();
    }
}
