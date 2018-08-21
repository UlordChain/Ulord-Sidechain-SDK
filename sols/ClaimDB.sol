pragma solidity ^0.4.24;

import "./SafeMath.sol";
import "./WhiteMange.sol";


contract ClaimDB is WhiteMange {
    using SafeMath for uint256;

    struct Claim {
        uint256     initDate;      // 上传资源的日期
        uint256     deposit;       // 押金
        uint256     price;         // 价格的定价，谁决定，出版商能加价吗？
        address     author;        // 作者
        uint8       types;         // 资源类型, 考虑一下用什么方式比较好
        bool        waive;         // 作者放弃。这个要考虑出版商和已购买者的问题。
        bool        forbidden;     // 资源是否被出版社禁止，监管
        string      udfs;          // udfs的hash值
    }

    mapping (bytes16 => Claim) private store_;


    /* 发布新资源 */
    event LogNewClaim(bytes16 _claimId, address indexed _author);

    /* 更新资源的内容 */
    event LogUpdateClaimUdfs(bytes16 _claimId, address indexed _author, uint256 _price);

    /* 更新资源的中的某个属性 */
    event LogUpdateClaimAuthor(bytes16 _claimId, address indexed _author, address indexed _newAuthor);
    event LogUpdateClaimPrice(bytes16 _claimId, address indexed _author, uint256 _newprice);
    event LogUpdateClaimWaive(bytes16 _claimId, address indexed _author, bool _waive);
    event LogUpdateClaimForbidden(bytes16 _claimId, bool _forbidden);

    event LogDeleteCLaim(bytes16 _claimId);


    constructor(address _owner) public {
        owner = _owner;
        whitelist_[msg.sender] = true;
    }

    /**
     * @dev 创建新的资源。
     * @param _cid     bytes16  : 资源id
     * @param _udfs    string   : 资源的UDFS Hash值
     * @param _author  address  : 发布者的地址
     * @param _price   uint256  : 资源的定价
     * @param _deposit uint256  : 发布资源收取的押金
     * @param _type    uint8    : 资源的类型，现阶段默认为1
     * @return         bool     : 操作成功返回true
     */
    function createClaim(bytes16 _cid, string _udfs, address _author, uint256 _price, uint256 _deposit, uint8 _type)
        public
        returns(bool)
    {
        if (whitelist_[msg.sender] != true){
            emit LogError(RScorr.Insufficient);
            return false;
        } // 检查调用者白名单权限

        if (isExist(_cid)){
            emit LogError(RScorr.ObjExist);
            return false;
        }// 保证这个资源不存在

        store_[_cid].author    = _author;
        store_[_cid].udfs     = _udfs;
        store_[_cid].initDate  = now;
        store_[_cid].deposit   = _deposit;
        store_[_cid].price     = _price;
        store_[_cid].waive      = false;
        store_[_cid].forbidden = false;
        store_[_cid].types     = _type;  //改一改哈

        emit LogNewClaim(_cid, _author);

        return true;
    }

    /**
     * @dev 更新资源的内容(UDFS),同时更新资源的定价
     * @param _cid       bytes16  : 资源id
     * @param _author    address  : 发布者的地址
     * @param _udfs      string   : 资源的新地址
     * @param _price     uint256  : 资源的新定价
     * @return           bool     : 操作成功返回true
     */
    function updateClaim(bytes16 _cid, address _author, string _udfs, uint256 _price)
        public
        returns(bool)
    {
        if (whitelist_[msg.sender] != true){
            emit LogError(RScorr.Insufficient);
            return false;
        } // 检查调用者白名单权限

        if(store_[_cid].author != _author) {
            emit LogError(RScorr.IdCertifyFailed);
            return false;
        } // 检查资源的作者是否为原作者


        store_[_cid].udfs = _udfs;
        store_[_cid].price = _price;

        emit LogUpdateClaimUdfs(_cid, _author, _price);

        return true;
    }


    /**
     * @dev 变更资源的作者地址，用于交易版权
     * @param _cid       bytes16  : 资源id
     * @param _author    address  : 发布者的地址
     * @param _newAuthor address  : 资源的新地址
     * @return           bool     : 操作成功返回true
     */
    function updateClaimAuthor(bytes16 _cid, address _author, address _newAuthor)
        public
        returns(bool)
    {
        /* Check the caller for white list permissions */
        if (whitelist_[msg.sender] != true){
            emit LogError(RScorr.Insufficient);
            return false;
        }

        if(store_[_cid].author != _author) {
            emit LogError(RScorr.IdCertifyFailed);
            return false;

        } // 检查资源的作者是否为原作者

        if(_newAuthor == address(0)) {
            emit LogError(RScorr.InvalidAddr);
            return false;
        }

        emit LogUpdateClaimAuthor(_cid, _author, _newAuthor);

        store_[_cid].author = _newAuthor;
        return true;
    }


    /**
     * @dev 变更资源的价格。
     * @dev 修改价格，是需要单边修改，还是双方同意的
     * @param _cid      bytes16  : 资源id
     * @param _author   address  : 发布者的地址
     * @param _newPrice address  : 资源的新价格
     * @return          bool     : 操作成功返回true
     */
    function updateClaimPrice(bytes16 _cid, address _author, uint256 _newPrice)
        public
        returns(bool)
    {
        if (whitelist_[msg.sender] != true){
            emit LogError(RScorr.Insufficient);
            return false;
        } // 检查调用者白名单权限

        if(store_[_cid].author != _author){
            emit LogError(RScorr.IdCertifyFailed);
            return false;
        } //验证资源的作者身份

        if(store_[_cid].price == _newPrice){
            emit LogError(RScorr.Insignificance);
            return false;
        } //更新的字段不能相同

        emit LogUpdateClaimPrice(_cid, _author, _newPrice);

        store_[_cid].price = _newPrice;
        return true;
    }

    /**
     * @dev 变更资源放弃的状态。
     * @param _cid     bytes16  : 资源id
     * @param _author  address  : 发布者的地址
     * @param _waive    bool    : 资源的是否放弃的标志，True代表放弃
     * @return          bool    : 操作成功返回true
     */
    function updateClaimWaive(bytes16 _cid, address _author, bool _waive)
        public
        returns(bool)
    {
        if (whitelist_[msg.sender] != true){
            emit LogError(RScorr.Insufficient);
            return false;
        }   // 检查调用者白名单权限

        if(store_[_cid].author != _author) {
            emit LogError(RScorr.IdCertifyFailed);
            return false;
        } // 验证资源的作者身份

        if(store_[_cid].waive == _waive) {
            emit LogError(RScorr.Insignificance);
            return false;
        }  //更新的字段不能相同

        emit LogUpdateClaimWaive(_cid, _author, _waive);
        store_[_cid].waive = _waive;

        return true;
    }

    /**
     * @dev 管理员变更资源的屏蔽状态。
     * @dev 此函数限制为只能由管理员调用
     * @param _cid       bytes16 : 资源id
     * @param _forbidden bool    : 资源的是否被屏蔽的标志，True代表屏蔽
     * @return           bool    : 操作成功返回true
     */
    function updateClaimForbidden(bytes16 _cid, bool _forbidden) public returns(bool){
        if(msg.sender != owner && msg.sender != admin){
            emit LogError(RScorr.PermissionDenied);
            return false;
        } // 检查管理员权限

        if(store_[_cid].author == address(0)) {
            emit LogError(RScorr.ObjNotExist);
            return false;
        } // 检查资源是否存在

        if(store_[_cid].forbidden == _forbidden) {
            emit LogError(RScorr.Insignificance);
            return false;
        } //更新的字段不能相同

        emit LogUpdateClaimForbidden(_cid,  _forbidden);

        store_[_cid].forbidden = _forbidden;
        return true;
    }

    /**
     * @dev 管理员删除资源。
     * @dev 此函数限制为只能由管理员调用
     * @param _cid      bytes16  : 资源id
     * @return          bool     : 操作成功返回true
     */
    function deleteClaim(bytes16 _cid)
        public
        returns(bool)
    {
        if(msg.sender != owner && msg.sender != admin){
            emit LogError(RScorr.PermissionDenied);
            return false;
        } // 检查管理员权限

        if(store_[_cid].author == address(0)) {
            emit LogError(RScorr.ObjNotExist);
            return false;
        } // 检查资源是否存在

        delete store_[_cid];

        emit LogDeleteCLaim(_cid);

        return true;
    }

    /////////////////////////
    /// View
    /////////////////////////

    /**
     * @dev 查找资源的详细信息。
     * @dev 此函数限制只让白名单中的地址查询。
     * @param _claimId   bytes16 : 资源的UPFS Hash值
     * @return                   : 指定资源的详细信息
     *                    author : 归属者
     *                      udfs : UDFS值
     *                  initDate : 发布时间
     *                   deposit : 押金
     *                     price : 定价
     *                     waive : 作者是否放弃
     *                     types : 类型
     */
    function getClaimInfoByID(bytes16 _claimId) public view returns(
        address author, string udfs, uint256 initDate, uint256 deposit,
        uint256 price,  bool  waive, uint8   types)
    {
        if(store_[_claimId].author == address(0) || whitelist_[msg.sender] == false) {
            return (0,"Null",0,0,0,true,0);
        }

        return (store_[_claimId].author,
        store_[_claimId].udfs,
        store_[_claimId].initDate,
        store_[_claimId].deposit,
        store_[_claimId].price,
        store_[_claimId].waive,
        //store_[_claimId].forbidden,
        store_[_claimId].types);
    }


    /**
     * @dev 判断资源是否存在
     * @param _claimId bytes16  : 资源id
     * @return            bool  : 存在返回true, 不存在返回false
     */
    function isExist(bytes16 _claimId)
        view
        public
        returns(bool)
    {
        if (store_[_claimId].author != address(0)){
            return true;
        }
        return false;
    }


    /**
     * @dev 检查资源是否能购买
     *  1. 资源不存在
     *  2. 定价为0，意味着免费
     *  3. waive 为0 ，意味着作者已经下架该资源
     * @param _claimId bytes16  : 资源id
     * @return         bool     : 可购买返回true
     */
    function isSaleable(bytes16 _claimId)
        view
        public
        returns(bool)
    {
        if (store_[_claimId].author == address(0) ||
        store_[_claimId].price == 0           ||
        store_[_claimId].waive == true)
        {
            return false;
        }
        return true;
    }


    /**
     * @dev 获取资源的购买信息
     * @notice 建议先用isSaleable判断一下。
     * @param _claimId bytes16  : 资源id
     * @return                  : 资源购买需要的信息，作者和定价
     *          author address  : 资源的地址
     *          price uint256   : 资源的定价
     */
    function getGoodsInfo(bytes16 _claimId)
        view
        public
        returns(address author, uint256 price)
    {
        return (store_[_claimId].author, store_[_claimId].price);
    }

}