pragma solidity ^0.8.0;

import "./VerseToken.sol";

contract RentalContractFactory {
    struct DeployedContract {
        address rentalContractAddress;
        bool exists;
    }

    mapping(uint256 => DeployedContract) public envIdToContract;

    function deployRentalContract(address versepropAddress, uint256 dailyRentFee, uint256 envId) external returns (address) {
        require(!envIdToContract[envId].exists, "Contract with this envId already exists");

        RentalContract newContract = new RentalContract(versepropAddress, dailyRentFee);
        address deployedContract = address(newContract);

        envIdToContract[envId] = DeployedContract({
            rentalContractAddress: deployedContract,
            exists: true
        });

        return deployedContract;
    }

    function getContractAddress(uint256 envId) external view returns (address) {
        require(envIdToContract[envId].exists, "Contract with this envId does not exist");
        return envIdToContract[envId].rentalContractAddress;
    }
}
