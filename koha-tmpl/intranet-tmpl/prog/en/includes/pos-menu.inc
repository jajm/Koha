<div id="navmenu">
    <div id="navmenulist">
        [% IF ( CAN_user_parameters_manage_cash_registers || CAN_user_parameters_manage_accounts) %]
        <h5>Administration</h5>
        <ul>
            [% IF ( CAN_user_parameters_manage_cash_registers ) %]
                <li><a href="/cgi-bin/koha/admin/cash_registers.pl">Configure cash registers</a></li>
            [% END %]

            [% IF ( CAN_user_parameters_manage_accounts ) %]
                <li><a href="/cgi-bin/koha/admin/debit_types.pl">Configure items for purchase</a></li>
            [% END %]
        </ul>
        [% END %]
    </div>
</div>
