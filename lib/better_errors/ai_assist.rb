# frozen_string_literal: true
require 'pycall'

module BetterErrors
  module AiAssist

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

    public def ai_assistance
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
        self explanatory correction or the errors in ruby or rails.
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

  end
end
