using GuardErp.Api.Security;

namespace GuardErp.Api.Reports;

public sealed class PayrollReportAuthorization
{
    public bool CanRead(UserRole role) =>
        role is UserRole.Administrator or UserRole.PayrollManager;

    public bool CanModify(UserRole role) =>
        role is UserRole.Administrator or UserRole.PayrollManager;
}
