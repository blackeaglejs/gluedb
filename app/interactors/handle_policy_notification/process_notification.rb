module HandlePolicyNotification
  class ProcessNotification
    include Interactor::Organizer

    organize(
      ::HandlePolicyNotification::ExtractPolicyDetails,
      ::HandlePolicyNotification::ExtractPlanDetails,
      ::HandlePolicyNotification::ExtractMemberDetails,
      ::HandlePolicyNotification::VerifyRequiredDetailsPresent,
      ::HandlePolicyNotification::FindInteractingPolicies,
      ::HandlePolicyNotification::FindRenewalCandidates
    )
  end
end
