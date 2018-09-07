pragma solidity ^0.4.24;
/**
 * @title 判断错误类型，
 * @dev 避免使用断言抛出异常，直接使用日志输出错误原因，
 * @dev 因为不能直接读取函数的返回值
 * 错误类型说明：
 */
contract ErrorModule {
    enum RScorr { 
        Success,
        Unknown,          // Unknown error
        InvalidAddr,      // 无效的地址
        InvalidStr,       // 无效的字符串
        InvalidClaimId,   // 无效的资源id
        InvalidUdfs,      // 无效的UDFS
        InvalidObj,       // 无效的对象，购买一个已放弃的资源 6

        Unsupported,      // 未授权
        ServStop,         // 服务停止

        ObjNotExist,      // 对象不存在
        ObjExist,         // 对象已存在  10

        ScantToken,       // 代币余额不充足
        ScantCredit,      // 代币授权额度不足
        Insolvent,        // 支付能力不足   13


        Insufficient,     // 白名单权限不足
        PermissionDenied, // 管理权限不足, 管理员权限
        IdCertifyFailed,  // 身份认证失败，作者身份认证

        Insignificance,   // 无意义的操作，更新的内容不变

        ClaimAbandoned,
        CidIsInvalid,
        UdfsInvalid, //udfs 无效
        Undefine01,
        Undefine02,
        Undefine03,
        Undefine04,
        Undefine05,
        Undefine06,
        Undefine07,
        Undefine08,
        Undefine09
    }

    event LogError(RScorr _errorNumber);
}
