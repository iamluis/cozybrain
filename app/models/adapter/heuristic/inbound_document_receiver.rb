# Heuristic implementation of Port::InboundDocumentReceiver. Regex over
# sender + subject. Concrete enough to be useful in dev/test and as a
# real first-pass classifier — most of Luis's inbound mail is from a
# handful of known senders (Ryanair, Santander, gestoría, etc.).
#
# Confidence is a coarse signal: 0.9 if both sender + subject match a
# rule, 0.7 if only one, 0.3 if no rule matched (kind: other).
# A future LLM adapter can use the same port and replace this.
module Adapter
  module Heuristic
    class InboundDocumentReceiver < Adapter::Base
      RULES = [
        {
          kind:           "email_invoice",
          folder:         "expenses",
          sender_pattern: /ryanair|easyjet|booking\.com|airbnb|amazon|notion|github|stripe|fly\.io/i,
          subject_pattern: /invoice|recibo|factura|booking|reservation|order #/i
        },
        {
          kind:           "bank_statement",
          folder:         "bank",
          sender_pattern: /santander|bbva|caixa|deutsche\s?bank|n26|wise/i,
          subject_pattern: /statement|extracto|cuenta|saldo|account summary/i
        },
        {
          kind:           "tax_doc",
          folder:         "tax",
          sender_pattern: /gestor[ií]a|aeat|hacienda/i,
          subject_pattern: /modelo\s?\d+|q[1-4]|aeat|hacienda|iva|irpf/i
        },
        {
          kind:           "corporate",
          folder:         "corporate",
          sender_pattern: /registr[oa]|notari|c[aá]mara/i,
          subject_pattern: /registro mercantil|escritura|acta|constituci[oó]n/i
        }
      ].freeze

      class << self
        def port_module
          Port::InboundDocumentReceiver
        end

        def _perform(input)
          from    = input["from"].to_s
          subject = input["subject"].to_s

          rule, confidence = best_match(from, subject)
          today = Date.current

          if rule.nil?
            {
              "classified_kind"        => "other",
              "confidence"             => 0.3,
              "suggested_folder"       => "expenses",
              "suggested_period_year"  => today.year,
              "suggested_period_month" => today.month
            }
          else
            {
              "classified_kind"        => rule[:kind],
              "confidence"             => confidence,
              "suggested_folder"       => rule[:folder],
              "suggested_period_year"  => today.year,
              "suggested_period_month" => today.month
            }
          end
        end

        private

        def best_match(from, subject)
          best = nil
          best_score = 0.0

          RULES.each do |rule|
            sender_hit  = from.match?(rule[:sender_pattern])
            subject_hit = subject.match?(rule[:subject_pattern])
            score =
              if sender_hit && subject_hit then 0.9
              elsif sender_hit               then 0.75
              elsif subject_hit              then 0.7
              else 0.0
              end

            if score > best_score
              best       = rule
              best_score = score
            end
          end

          [ best, best_score ]
        end
      end
    end
  end
end
