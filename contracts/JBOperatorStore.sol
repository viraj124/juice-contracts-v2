// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './interfaces/IJBOperatorStore.sol';

// --------------------------- custom errors -------------------------- //
//*********************************************************************//
error PERMISSION_INDEX_OUT_OF_BOUNDS();

/** 
  @notice
  Stores operator permissions for all addresses. Addresses can give permissions to any other address to take specific indexed actions on their behalf.
*/
contract JBOperatorStore is IJBOperatorStore {
  //*********************************************************************//
  // --------------------- public stored properties -------------------- //
  //*********************************************************************//

  /** 
    @notice
    The permissions that an operator has to operate on a specific domain.
    
    @dev
    An account can give an operator permissions that only pertain to a specific domain.
    There is no domain with a value of 0 – accounts can use the 0 domain to give an operator
    permissions to all domains on their behalf.

    _operator The address of the operator.
    _account The address of the account being operated.
    _domain The domain within which the permissions apply.
  */
  mapping(address => mapping(address => mapping(uint256 => uint256))) public override permissionsOf;

  //*********************************************************************//
  // ------------------------- external views -------------------------- //
  //*********************************************************************//

  /** 
    @notice 
    Whether or not an operator has the permission to take a certain action pertaining to the specified domain.

    @param _operator The operator to check.
    @param _account The account that has given out permissions to the operator.
    @param _domain The domain that the operator has been given permissions to operate.
    @param _permissionIndex The permission indexes to check for.

    @return Whether the operator has the specified permission.
  */
  function hasPermission(
    address _operator,
    address _account,
    uint256 _domain,
    uint256 _permissionIndex
  ) external view override returns (bool) {
    if (_permissionIndex > 255) {
      revert PERMISSION_INDEX_OUT_OF_BOUNDS();
    }
    return (((permissionsOf[_operator][_account][_domain] >> _permissionIndex) & 1) == 1);
  }

  /** 
    @notice 
    Whether or not an operator has the permission to take certain actions pertaining to the specified domain.

    @param _operator The operator to check.
    @param _account The account that has given out permissions to the operator.
    @param _domain The domain that the operator has been given permissions to operate.
    @param _permissionIndexes An array of permission indexes to check for.

    @return Whether the operator has all specified permissions.
  */
  function hasPermissions(
    address _operator,
    address _account,
    uint256 _domain,
    uint256[] calldata _permissionIndexes
  ) external view override returns (bool) {
    for (uint256 _i = 0; _i < _permissionIndexes.length; _i++) {
      uint256 _permissionIndex = _permissionIndexes[_i];
      if (_permissionIndex > 255) {
        revert PERMISSION_INDEX_OUT_OF_BOUNDS();
      }
      if (((permissionsOf[_operator][_account][_domain] >> _permissionIndex) & 1) == 0)
        return false;
    }
    return true;
  }

  //*********************************************************************//
  // ---------------------- external transactions ---------------------- //
  //*********************************************************************//

  /**
    @notice
    Sets permissions for an operators.

    @dev
    Only an address can set its own operators.

    @param _operatorData The data that specifies the params for the operator being set.
      @dev _operatorData.operators The operators to whom permissions will be given.
      @dev _operatorData.domains Lists the domain that each operator is being given permissions to operate. A value of 0 serves as a wildcard domain. Applications can specify their own domain system.
      @dev _operatorData.permissionIndexes Lists the permission indexes to set for each operator. Indexes must be between 0-255. Applications can specify the significance of each index.
  */
  function setOperator(JBOperatorData calldata _operatorData) external override {
    // Pack the indexes into a uint256.
    uint256 _packed = _packedPermissions(_operatorData.permissionIndexes);

    // Store the new value.
    permissionsOf[_operatorData.operator][msg.sender][_operatorData.domain] = _packed;

    emit SetOperator(
      _operatorData.operator,
      msg.sender,
      _operatorData.domain,
      _operatorData.permissionIndexes,
      _packed
    );
  }

  /**
    @notice
    Sets permissions for many operators.

    @dev
    Only an address can set its own operators.

    @param _operatorData The data that specifies the params for each operator being set.
      @dev _operatorData.operators The operators to whom permissions will be given.
      @dev _operatorData.domains Lists the domain that each operator is being given permissions to operate. A value of 0 serves as a wildcard domain. Applications can specify their own domain system.
      @dev _operatorData.permissionIndexes Lists the permission indexes to set for each operator. Indexes must be between 0-255. Applications can specify the significance of each index.
  */
  function setOperators(JBOperatorData[] calldata _operatorData) external override {
    for (uint256 _i = 0; _i < _operatorData.length; _i++) {
      // Pack the indexes into a uint256.
      uint256 _packed = _packedPermissions(_operatorData[_i].permissionIndexes);

      // Store the new value.
      permissionsOf[_operatorData[_i].operator][msg.sender][_operatorData[_i].domain] = _packed;

      emit SetOperator(
        _operatorData[_i].operator,
        msg.sender,
        _operatorData[_i].domain,
        _operatorData[_i].permissionIndexes,
        _packed
      );
    }
  }

  //*********************************************************************//
  // --------------------- private helper functions -------------------- //
  //*********************************************************************//

  /** 
    @notice 
    Converts an array of permission indexes to a packed uint256.

    @param _indexes The indexes of the permissions to pack.

    @return packed The packed result.
  */
  function _packedPermissions(uint256[] calldata _indexes) private pure returns (uint256 packed) {
    for (uint256 _i = 0; _i < _indexes.length; _i++) {
      uint256 _index = _indexes[_i];
      if (_index > 255) {
        revert PERMISSION_INDEX_OUT_OF_BOUNDS();
      }
      // Turn the bit at the index on.
      packed |= 1 << _index;
    }
  }
}
