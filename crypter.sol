// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.0 <0.9.0;

library OduEncrypt {


    function encrypt(bytes memory data, bytes memory key) public view returns(bool, string memory, bytes memory output) {
        bytes32 dataHash    = keccak256(data);
        bytes memory keyHash = abi.encodePacked(keccak256(abi.encodePacked(key)));
        bytes memory cipher = data;
        uint  random        = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % (256 + 1);
        uint256 random2 = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c).balance;
        uint256 randomState = uint256(keccak256(abi.encodePacked(uint8(bytes1(bytes1(uint8(random2)))), random)));
        uint256  randomBigInt = ((random + 256) ** 28);
        bytes memory salt = abi.encodePacked(keccak256(abi.encodePacked(keyHash)), keccak256(abi.encodePacked(randomBigInt)));
        (bytes memory compound) = getCompound(salt, keyHash, abi.encodePacked(randomBigInt, randomState));
        
        for (uint i1 = 0; i1 < cipher.length; i1++) { 
            bytes1 HexChar = cipher[uint8(i1)];
            uint HexIndex = uint8(bytes1(HexChar));

            cipher[uint8(i1)] = compound[uint8(HexIndex)];
        }
        cipher = abi.encodePacked(cipher, bytes1(uint8(random)), bytes1(uint8(random2)) );
        bytes memory decryptBytes = decrypt(cipher, key);
        bytes32 decryptHash = keccak256(decryptBytes);
        if(dataHash != decryptHash){
            //return (false, "RETRY", bytes(""));
            return (false, "RETRY", cipher);
        }
 
        return (true, "SUCCESS", cipher);
    }


    function decrypt(bytes memory data, bytes memory key) public pure returns(bytes memory) {
        bytes memory keyHash = abi.encodePacked(keccak256(abi.encodePacked(key)));
        bytes memory cipher;
        uint  random        = uint(uint8(bytes1(data[data.length-2])));
        uint256 random2 = uint(uint8(bytes1(data[data.length-1])));
        uint256 randomState = uint256(keccak256(abi.encodePacked(uint8(bytes1(bytes1(uint8(random2)))), random)));
        uint256  randomBigInt = ((random + 256) ** 28);
        bytes memory salt = abi.encodePacked(keccak256(abi.encodePacked(keyHash)), keccak256(abi.encodePacked(randomBigInt)));
        (bytes memory compound) = getCompound(salt, keyHash, abi.encodePacked(randomBigInt, randomState));

        for (uint i0 = 0; i0 < data.length-2; i0++) { 
            for (uint i1 = 0; i1 < 256; i1++) {
                if(data[uint8(i0)] == compound[uint8(i1)]){
                   cipher = abi.encodePacked(cipher, bytes1(uint8(i1)));
                    break;
                }
             }
        }

        return (cipher);
    }


    function getCompound(bytes memory salt, bytes memory key, bytes memory randomBigInt) public pure returns(bytes memory) {
        uint256  SaltInt = uint256(keccak256(abi.encodePacked(salt)));
        uint256  KeyInt = uint256(keccak256(abi.encodePacked(keccak256(abi.encodePacked(key)), keccak256(abi.encodePacked(SaltInt)))));
        uint256  randomInt = uint256(keccak256(abi.encodePacked(keccak256(abi.encodePacked(randomBigInt)), keccak256(abi.encodePacked(SaltInt)))));

        (bytes memory _getCompound1) = getCompound1(SaltInt, KeyInt, randomInt);
        (bytes memory _getCompound2) = getCompound2(SaltInt, KeyInt, randomInt);
        return abi.encodePacked(_getCompound1, _getCompound2);
    }

    function getCompound1(uint256 StateInt, uint256 KeyInt, uint256 randomInt) internal pure returns(bytes memory) {
        bytes32  compound1 = bytes32(StateInt  % KeyInt  % randomInt);
        bytes32  compound2 = bytes32(KeyInt  % randomInt  % StateInt);
        bytes32  compound3 = bytes32(randomInt  % StateInt  % KeyInt);
        bytes32  compound4 = bytes32(randomInt  % StateInt  % KeyInt % type(uint256).max);
        return abi.encodePacked(compound1, compound2, compound3, compound4);
    }

    function getCompound2(uint256 StateInt, uint256 KeyInt, uint256 randomInt) internal pure returns(bytes memory) {
        bytes32  compound5 = bytes32(StateInt  % randomInt  % KeyInt);
        bytes32  compound6 = bytes32(KeyInt  % StateInt  % randomInt);
        bytes32  compound7 = bytes32(randomInt  % KeyInt  % StateInt);
        bytes32  compound8 = bytes32(randomInt  % KeyInt  % StateInt % type(uint256).max);
        return abi.encodePacked(compound5, compound6, compound7, compound8);
    }

}