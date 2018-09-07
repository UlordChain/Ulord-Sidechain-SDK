pragma solidity ^0.4.24;
library StrFilter{

    /**
     * @dev 简单的检查一下HASH串的有效性
     * @param _input string
     * @return bool
     */
    function udfsFilter(string _input)
        internal
        pure
        returns(bool)
    {
        bytes memory _temp = bytes(_input);

        // length == 46 , Qm开头
        if (_temp.length == 46 &&
            _temp[0] == 0x51   &&
            _temp[1] == 0x6D   ){
            return true;
        }
        return false;
    }
}