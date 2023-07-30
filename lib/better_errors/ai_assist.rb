# frozen_string_literal: true
require 'pycall'
require 'redcarpet'


module BetterErrors
  module AiAssist
    DEFAULT_AI_ASSIST_METHOD = :ai_assistance_chatgpt_only.freeze

    private def ai_assist_context_stacktrace
      stack_trace = ""
      application_frames.each_with_index do |frame, index|
        stack_trace += "#{index}: context:#{frame.context} #{frame.class_name}#{frame.method_name} file: #{frame.pretty_path} on line #{frame.line}\n"
      end
      stack_trace
    end

    private def chat_gpt_prompt
      context = <<~CONTEXT
        Rails Exception Type: #{exception_type} at #{request_path}

        Rails Exception Message: #{exception_message}

        Rails Exception Hint: #{exception_hint}

        Source Code Error Context:
        #{ErrorPage.text_formatted_code_block application_frames[0]}

        Stack Trace:
        #{ai_assist_context_stacktrace}
      CONTEXT
      # Rails.logger.info("chat gpt context:\n#{context}")
      context
    end

    private def ai_assist_method
      @ai_assist_method || DEFAULT_AI_ASSIST_METHOD
    end

    public def ai_assistance_chatgpt_only
      chatOpenAI = PyCall.import_module("langchain.chat_models").ChatOpenAI
      aIMessage = PyCall.import_module("langchain.schema").AIMessage
      humanMessage = PyCall.import_module("langchain.schema").HumanMessage
      systemMessage = PyCall.import_module("langchain.schema").SystemMessage

      raise Exception.new("OPENAI_API_KEY not defined in environment") unless ENV['OPENAI_API_KEY']

      llm = chatOpenAI.new(temperature: 0,
                           model_name: "gpt-3.5-turbo",
                           openai_api_key: ENV['OPENAI_API_KEY'])

      default_task = <<~TASK
        You are to look for the errors in the given code and respond back with a brief but
        self explanatory correction or the errors in ruby or rails. Put this into a readable 
        markdown string format with sections for issue and solution. Take note that if the string includes a symbol like :some_symbol, wrap this in backticks for inline markdown.
      TASK

      default_task_plus_example = <<~TASK
        #{default_task} Please show a working example in ruby or rails.
      TASK

      messages = [
        systemMessage.new(content: default_task),
        humanMessage.new(content: chat_gpt_prompt)
      ]

      answer = llm.call(messages)
      # Rails.logger.info("chat gpt answer:\n#{answer.content}")
      answer.content
    end

    public def ai_assistance_google_and_chatgpt
      "google and chat gpt not implemented yet"
    end

    public def config_ai_assist(ai_assist_method)
      @ai_assist_method = ai_assist_method.freeze
    end

    public def ai_assistance
      #config_ai_assist("ai_assistance_google_and_chatgpt")
      logger = Rails.logger
      logger.info("ai_assistance called: ai method:#{ai_assist_method}")

      str = self.public_send(ai_assist_method)
      format_markdown(str)
    end

    private def format_markdown(md_text)
      options = {
        filter_html:     true,
        hard_wrap:       true,
        link_attributes: { rel: 'nofollow', target: "_blank" },
        space_after_headers: true,
        fenced_code_blocks: true
      }
      extensions = {
        autolink:           true,
        superscript:        true,
        disable_indented_code_blocks: true
      }

      renderer = ::Redcarpet::Render::HTML.new(options = {})
      markdown = ::Redcarpet::Markdown.new(renderer, extensions = {})
      markdown.render(md_text).html_safe
    end
  end
end
