// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./VerseToken.sol";

contract RentalContractFactory {
    struct DeployedContract {
        address rentalContractAddress;
        bool exists;
    }

    mapping(string => DeployedContract) public envIdToContract;

    function deployRentalContract(
        address payable versepropAddress,
        uint256 dailyRentFee,
        string memory envId,
        uint256 mintLimit,
        string memory tokenUri
    ) external returns (address) {
        require(
            !envIdToContract[envId].exists,
            "Contract with this envId already exists"
        );

        RentalContract newContract = new RentalContract(
            versepropAddress,
            dailyRentFee,
            mintLimit,
            tokenUri
        );
        address deployedContract = address(newContract);

        envIdToContract[envId] = DeployedContract({
            rentalContractAddress: deployedContract,
            exists: true
        });

        return deployedContract;
    }

    function getContractAddress(
        string memory envId
    ) external view returns (address) {
        require(
            envIdToContract[envId].exists,
            "Contract with this envId does not exist"
        );
        return envIdToContract[envId].rentalContractAddress;
    }
}
