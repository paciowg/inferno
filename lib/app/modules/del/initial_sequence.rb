module Inferno
    module Sequence
        class InitialSequence < SequenceBase
  
            title 'Initial DEL Sequence'
            description "Verify something something something CMS's Data Element Library Implementation Guide"
            test_id_prefix 'InitialDEL'

            test 'First DEL test' do
            
                metadata{
                    id '01'
                    desc %(
                        This is the first test of the DEL Implementation Guide
                    )
                }

                assert true

                warning{
                    assert false, "You've been warned!"
                }

            end

        end
    end 
end
