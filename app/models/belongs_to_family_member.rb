module BelongsToFamilyMember
  def family_member
    return nil unless family
    family.family_members.detect { |apl| family_member_id == apl._id }
  end

  def family_member=(family_member)
    return unless family_member.is_a? FamilyMember
    self.family_member_id = family_member._id
  end
end
