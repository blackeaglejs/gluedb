require 'rgl/adjacency'
require 'rgl/topsort'

module Handlers
  class EnrollmentEventEnrichHandler < ::Handlers::Base

    # Takes a 'bucket' of enrollment event notifications and transforms them
    # into a concrete set of enrollment actions.  We then invoke the step
    # after us once for each in that set.
    # [::ExternalEvents::EnrollmentEventNotification] -> [::EnrollmentAction::Base]
    def call(context)
      no_bogus_terms = discard_bogus_terms(context)
      no_bogus_plan_years = discard_bogus_plan_years(no_bogus_terms)
      sorted_actions = sort_enrollment_events(no_bogus_plan_years)
      clean_sorted_list = discard_bogus_renewal_terms(sorted_actions)
      enrollment_sets = chunk_enrollments(clean_sorted_list)
      resolve_actions(enrollment_sets).each do |action|
        super(action)
      end
    end

    def discard_bogus_plan_years(enrollments)
      _dropped, keep = enrollments.partition { |en| en.drop_if_bogus_plan_year! }
      _dropped = nil
      keep
    end

    def discard_bogus_terms(enrollments)
      aw = ArrayWindow.new(enrollments)
      aw.each do |items|
        current, before, after = items
        current.check_for_bogus_term_against(before + after)
      end
      _dropped, keep = enrollments.partition { |en| en.drop_if_bogus_term! }
      _dropped = nil
      keep
    end

    # If we have a termination on a policy which crosses a plan year,
    # and that termination is the normal end day of the plan anyway,
    # discard the termination - we will generate our own and it confuses us.
    # We're doing this because we can't always rely on this termination being
    # generated by enroll.
    def discard_bogus_renewal_terms(enrollments)
      enrollments.each_cons(2) do |a, b|
        a.check_for_bogus_renewal_term_against(b)
      end
      _dropped, keep = enrollments.partition { |en| en.drop_if_bogus_renewal_term! } 
      _droppped = nil
      keep
    end

    def sort_enrollment_events(events)
      order_graph = RGL::DirectedAdjacencyGraph.new
      events.each do |ev|
        order_graph.add_vertex(ev)
      end
      events.permutation(2).each do |perm|
        a, b = perm
        a.edge_for(order_graph, b)
      end
      iter = order_graph.topsort_iterator
      results = []
      iter.each do |ev|
        results << ev
      end
      results
    end

    def chunk_enrollments(enrollments)
      aw = ArrayWindow.new(enrollments)
      aw.chunk_adjacent do |a, b|
        !a.is_adjacent_to?(b)
      end
    end

    def resolve_actions(enrollment_set)
      actions = []
      enrollment_set.each do |chunk|
        if !chunk.empty?
          action = EnrollmentAction::Base.select_action_for(chunk)
          if action
            actions << action
          end
        end
      end
      actions
    end
  end
end
