[%- BLOCK account_type_description -%]
    <span>
    [%- IF account.credit_type_code -%]
        [%- SWITCH account.credit_type_code -%]
            [%- CASE 'PAYMENT'          -%]Payment
            [%- CASE 'WRITEOFF'         -%]Writeoff
            [%- CASE 'FORGIVEN'         -%]Forgiven
            [%- CASE 'CREDIT'           -%]Credit
            [%- CASE 'LOST_FOUND'       -%]Lost item fee refund
            [%- CASE 'Refund'           -%]Refund
            [%- CASE                    -%][% account.credit_type.description | html %]
        [%- END -%]
    [%- ELSIF account.debit_type_code -%]
       [%- SWITCH account.debit_type_code -%]
           [%- CASE 'ACCOUNT'          -%]Account creation fee
           [%- CASE 'ACCOUNT_RENEW'    -%]Account renewal fee
           [%- CASE 'LOST'             -%]Lost item
           [%- CASE 'MANUAL'           -%]Manual fee
           [%- CASE 'NEW_CARD'         -%]New card
           [%- CASE 'OVERDUE'          -%]Fine
           [%- CASE 'PROCESSING'       -%]Lost item processing fee
           [%- CASE 'RENT'             -%]Rental fee
           [%- CASE 'RENT_DAILY'       -%]Daily rental fee
           [%- CASE 'RENT_RENEW'       -%]Renewal of rental item
           [%- CASE 'RENT_DAILY_RENEW' -%]Rewewal of daily rental item
           [%- CASE 'RESERVE'          -%]Hold fee
           [%- CASE 'RESERVE_EXPIRED'  -%]Hold waiting too long
           [%- CASE 'Payout'           -%]Payout
           [%- CASE                    -%][% account.debit_type.description | html %]
       [%- END -%]
    [%- END -%]
    [%- PROCESS account_status_description account=account -%]
    </span>
[%- END -%]

[%- BLOCK offset_type_description -%]
    [%- SWITCH account_offset.type -%]
        [%- CASE 'Credit Applied' -%]<span>Credit applied</span>
        [%- CASE 'Payment'        -%]<span>Payment</span>
        [%- CASE 'Manual Credit'  -%]<span>Manual credit</span>
        [%- CASE 'Manual Debit'   -%]<span>Manual invoice</span>
        [%- CASE 'Lost Item'      -%]<span>Lost item returned</span>
        [%- CASE 'Writeoff'       -%]<span>Writeoff</span>
        [%- CASE 'Void Payment'   -%]<span>Void payment</span>
        [%- CASE                  -%][% account_offset.type | html %]
    [%- END -%]
[%- END -%]

[%- BLOCK account_status_description -%]
    [%- SWITCH account.status -%]
        [%- CASE 'UNRETURNED' -%]<span> (Accruing)</span>
        [%- CASE 'RETURNED'   -%]<span> (Returned)</span>
        [%- CASE 'REPLACED'   -%]<span> (Replaced)</span>
        [%- CASE 'REFUNDED'   -%]<span> (Refunded)</span>
        [%- CASE 'FORGIVEN'   -%]<span> (Forgiven)</span>
        [%- CASE 'VOID'       -%]<span> (Voided)</span>
        [%- CASE 'LOST'       -%]<span> (Lost)</span>
        [%- CASE              -%]
    [%- END -%]
[%- END -%]
