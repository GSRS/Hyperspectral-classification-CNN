function net = Salinas_cnn_cifar_init_nin(varargin)
opts.networkType = 'simplenn' ;
opts = vl_argparse(opts, varargin) ;

% CIFAR-10 model from
% M. Lin, Q. Chen, and S. Yan. Network in network. CoRR,
% abs/1312.4400, 2013.
%
% It reproduces the NIN + Dropout result of Table 1 (<= 10.41% top1 error).

net.layers = {} ;

lr = [1 10] ;

% Block 1
net.layers{end+1} = struct('type', 'conv', ...
                           'name', 'conv1', ...
                           'weights', {init_weights(5,1,192)}, ...
                           'learningRate', lr, ...
                           'stride', 1, ...
                           'pad', 2) ;
net.layers{end+1} = struct('type', 'relu', 'name', 'relu1') ;
net.layers{end+1} = struct('type', 'conv', ...
                           'name', 'cccp1', ...
                           'weights', {init_weights(1,192,160)}, ...
                           'learningRate', lr, ...
                           'stride', 1, ...
                           'pad', 0) ;
net.layers{end+1} = struct('type', 'relu', 'name', 'relu_cccp1') ;
net.layers{end+1} = struct('type', 'conv', ...
                           'name', 'cccp2', ...
                           'weights', {init_weights(1,160,96)}, ...
                           'learningRate', lr, ...
                           'stride', 1, ...
                           'pad', 0) ;
net.layers{end+1} = struct('type', 'relu', 'name', 'relu_cccp2') ;
net.layers{end+1} = struct('name', 'pool1', ...
                           'type', 'pool', ...
                           'method', 'max', ...
                           'pool', [3 3], ...
                           'stride', 2, ...
                           'pad', 0) ;
net.layers{end+1} = struct('type', 'dropout', 'name', 'dropout1', 'rate', 0.5) ;%6*6

% Block 2
net.layers{end+1} = struct('type', 'conv', ...
                           'name', 'conv2', ...
                           'weights', {init_weights(5,96,192)}, ...
                           'learningRate', lr, ...
                           'stride', 1, ...
                           'pad', 2) ;
net.layers{end+1} = struct('type', 'relu', 'name', 'relu2') ;
net.layers{end+1} = struct('type', 'conv', ...
                           'name', 'cccp3', ...
                           'weights', {init_weights(1,192,192)}, ...
                           'learningRate', lr, ...
                           'stride', 1, ...
                           'pad', 0) ;
net.layers{end+1} = struct('type', 'relu', 'name', 'relu_cccp3') ;
net.layers{end+1} = struct('type', 'conv', ...
                           'name', 'cccp4', ...
                           'weights', {init_weights(1,192,192)}, ...
                           'learningRate', lr, ...
                           'stride', 1, ...
                           'pad', 0) ;
net.layers{end+1} = struct('type', 'relu', 'name', 'relu_cccp4') ;
net.layers{end+1} = struct('name', 'pool2', ...
                           'type', 'pool', ...
                           'method', 'avg', ...
                           'pool', [3 3], ...
                           'stride', 2, ...
                           'pad', 0) ;
net.layers{end+1} = struct('type', 'dropout', 'name', 'dropout2', 'rate', 0.5) ;%2*2

% Block 3
net.layers{end+1} = struct('type', 'conv', ...
                           'name', 'conv3', ...
                           'weights', {init_weights(3,192,192)}, ...
                           'learningRate', lr, ...
                           'stride', 1, ...
                           'pad', 1) ;
net.layers{end+1} = struct('type', 'relu', 'name', 'relu3') ;
net.layers{end+1} = struct('type', 'conv', ...
                           'name', 'cccp5', ...
                           'weights', {init_weights(1,192,192)}, ...
                           'learningRate', lr, ...
                           'stride', 1, ...
                           'pad', 0) ;
net.layers{end+1} = struct('type', 'relu', 'name', 'relu_cccp5') ;
net.layers{end+1} = struct('type', 'conv', ...
                           'name', 'cccp6', ...
                           'weights', {init_weights(1,192,16)}, ...
                           'learningRate', 0.001*lr, ...
                           'stride', 1, ...
                           'pad', 0) ;
net.layers{end}.weights{1} = 0.1 * net.layers{end}.weights{1} ;
%net.layers{end+1} = struct('type', 'relu', 'name', 'relu_cccp6') ;
net.layers{end+1} = struct('type', 'pool', ...
                           'name', 'pool3', ...
                           'method', 'avg', ...
                           'pool', [2 2], ...
                           'stride', 1, ...
                           'pad', 0) ;

% Loss layer
net.layers{end+1} = struct('type', 'softmaxloss') ;

% Meta parameters
net.meta.inputSize = [14 14 1] ;
net.meta.trainOpts.learningRate = [0.002, 0.01, 0.02, 0.04 * ones(1,80), 0.004 * ones(1,10), 0.0004 * ones(1,10)] ;
net.meta.trainOpts.weightDecay = 0.0005 ;
net.meta.trainOpts.batchSize = 100 ;
net.meta.trainOpts.numEpochs = numel(net.meta.trainOpts.learningRate) ;

% Fill in default values
net = vl_simplenn_tidy(net) ;

% Switch to DagNN if requested
switch lower(opts.networkType)
  case 'simplenn'
    % done
  case 'dagnn'
    net = dagnn.DagNN.fromSimpleNN(net, 'canonicalNames', true) ;
    net.addLayer('error', dagnn.Loss('loss', 'classerror'), ...
      {'prediction','label'}, 'error') ;
  otherwise
    assert(false) ;
end

function weights = init_weights(k,m,n)
weights{1} = randn(k,k,m,n,'single') * sqrt(2/(k*k*m)) ;
weights{2} = zeros(n,1,'single') ;