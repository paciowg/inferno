module Inferno
    module Sequence
      class FirstCustomSequence < SequenceBase
  
        title "Jake's First Custom Sequence"
  
        test_id_prefix 'JFCS'
  
        requires :url
        defines :oauth_authorize_endpoint, :oauth_token_endpoint, :oauth_register_endpoint
  
        description 'This is the first test sequence Jake has written'
  
        test 'First test in the JFCS sequence' do
  
          metadata {
            id '01'
            desc %(
  
             This is the first test of the sequence, and it just asserts true
  
            )
          }
  
          assert true
  
          warning {
            assert false, "You've been warned!"
          }
        end
  
      end
    end
  end
  